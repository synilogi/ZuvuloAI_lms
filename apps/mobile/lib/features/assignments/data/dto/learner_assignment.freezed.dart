// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'learner_assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssignmentWork {

 String get text; List<Attachment> get files; BirthDetails? get chart;
/// Create a copy of AssignmentWork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignmentWorkCopyWith<AssignmentWork> get copyWith => _$AssignmentWorkCopyWithImpl<AssignmentWork>(this as AssignmentWork, _$identity);

  /// Serializes this AssignmentWork to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignmentWork&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.files, files)&&(identical(other.chart, chart) || other.chart == chart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(files),chart);

@override
String toString() {
  return 'AssignmentWork(text: $text, files: $files, chart: $chart)';
}


}

/// @nodoc
abstract mixin class $AssignmentWorkCopyWith<$Res>  {
  factory $AssignmentWorkCopyWith(AssignmentWork value, $Res Function(AssignmentWork) _then) = _$AssignmentWorkCopyWithImpl;
@useResult
$Res call({
 String text, List<Attachment> files, BirthDetails? chart
});


$BirthDetailsCopyWith<$Res>? get chart;

}
/// @nodoc
class _$AssignmentWorkCopyWithImpl<$Res>
    implements $AssignmentWorkCopyWith<$Res> {
  _$AssignmentWorkCopyWithImpl(this._self, this._then);

  final AssignmentWork _self;
  final $Res Function(AssignmentWork) _then;

/// Create a copy of AssignmentWork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? files = null,Object? chart = freezed,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>,chart: freezed == chart ? _self.chart : chart // ignore: cast_nullable_to_non_nullable
as BirthDetails?,
  ));
}
/// Create a copy of AssignmentWork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BirthDetailsCopyWith<$Res>? get chart {
    if (_self.chart == null) {
    return null;
  }

  return $BirthDetailsCopyWith<$Res>(_self.chart!, (value) {
    return _then(_self.copyWith(chart: value));
  });
}
}


/// Adds pattern-matching-related methods to [AssignmentWork].
extension AssignmentWorkPatterns on AssignmentWork {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssignmentWork value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssignmentWork() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssignmentWork value)  $default,){
final _that = this;
switch (_that) {
case _AssignmentWork():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssignmentWork value)?  $default,){
final _that = this;
switch (_that) {
case _AssignmentWork() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  List<Attachment> files,  BirthDetails? chart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssignmentWork() when $default != null:
return $default(_that.text,_that.files,_that.chart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  List<Attachment> files,  BirthDetails? chart)  $default,) {final _that = this;
switch (_that) {
case _AssignmentWork():
return $default(_that.text,_that.files,_that.chart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  List<Attachment> files,  BirthDetails? chart)?  $default,) {final _that = this;
switch (_that) {
case _AssignmentWork() when $default != null:
return $default(_that.text,_that.files,_that.chart);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssignmentWork extends AssignmentWork {
  const _AssignmentWork({this.text = '', final  List<Attachment> files = const <Attachment>[], this.chart}): _files = files,super._();
  factory _AssignmentWork.fromJson(Map<String, dynamic> json) => _$AssignmentWorkFromJson(json);

@override@JsonKey() final  String text;
 final  List<Attachment> _files;
@override@JsonKey() List<Attachment> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

@override final  BirthDetails? chart;

/// Create a copy of AssignmentWork
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignmentWorkCopyWith<_AssignmentWork> get copyWith => __$AssignmentWorkCopyWithImpl<_AssignmentWork>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssignmentWorkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssignmentWork&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._files, _files)&&(identical(other.chart, chart) || other.chart == chart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_files),chart);

@override
String toString() {
  return 'AssignmentWork(text: $text, files: $files, chart: $chart)';
}


}

/// @nodoc
abstract mixin class _$AssignmentWorkCopyWith<$Res> implements $AssignmentWorkCopyWith<$Res> {
  factory _$AssignmentWorkCopyWith(_AssignmentWork value, $Res Function(_AssignmentWork) _then) = __$AssignmentWorkCopyWithImpl;
@override @useResult
$Res call({
 String text, List<Attachment> files, BirthDetails? chart
});


@override $BirthDetailsCopyWith<$Res>? get chart;

}
/// @nodoc
class __$AssignmentWorkCopyWithImpl<$Res>
    implements _$AssignmentWorkCopyWith<$Res> {
  __$AssignmentWorkCopyWithImpl(this._self, this._then);

  final _AssignmentWork _self;
  final $Res Function(_AssignmentWork) _then;

/// Create a copy of AssignmentWork
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? files = null,Object? chart = freezed,}) {
  return _then(_AssignmentWork(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>,chart: freezed == chart ? _self.chart : chart // ignore: cast_nullable_to_non_nullable
as BirthDetails?,
  ));
}

/// Create a copy of AssignmentWork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BirthDetailsCopyWith<$Res>? get chart {
    if (_self.chart == null) {
    return null;
  }

  return $BirthDetailsCopyWith<$Res>(_self.chart!, (value) {
    return _then(_self.copyWith(chart: value));
  });
}
}


/// @nodoc
mixin _$LearnerAssignment {

 CourseAssignment get assignment; String get courseTitle; String? get chapterTitle; String? get lessonId;@JsonKey(unknownEnumValue: AssignmentState.unknown) AssignmentState get state;/// When it is due **for this learner** — the server works a relative deadline out from when
/// their chapter opened.
@NullableUtcDateTimeConverter() DateTime? get dueAt; Submission? get submission; AssignmentWork? get draft;
/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerAssignmentCopyWith<LearnerAssignment> get copyWith => _$LearnerAssignmentCopyWithImpl<LearnerAssignment>(this as LearnerAssignment, _$identity);

  /// Serializes this LearnerAssignment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerAssignment&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.state, state) || other.state == state)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.submission, submission) || other.submission == submission)&&(identical(other.draft, draft) || other.draft == draft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignment,courseTitle,chapterTitle,lessonId,state,dueAt,submission,draft);

@override
String toString() {
  return 'LearnerAssignment(assignment: $assignment, courseTitle: $courseTitle, chapterTitle: $chapterTitle, lessonId: $lessonId, state: $state, dueAt: $dueAt, submission: $submission, draft: $draft)';
}


}

/// @nodoc
abstract mixin class $LearnerAssignmentCopyWith<$Res>  {
  factory $LearnerAssignmentCopyWith(LearnerAssignment value, $Res Function(LearnerAssignment) _then) = _$LearnerAssignmentCopyWithImpl;
@useResult
$Res call({
 CourseAssignment assignment, String courseTitle, String? chapterTitle, String? lessonId,@JsonKey(unknownEnumValue: AssignmentState.unknown) AssignmentState state,@NullableUtcDateTimeConverter() DateTime? dueAt, Submission? submission, AssignmentWork? draft
});


$CourseAssignmentCopyWith<$Res> get assignment;$SubmissionCopyWith<$Res>? get submission;$AssignmentWorkCopyWith<$Res>? get draft;

}
/// @nodoc
class _$LearnerAssignmentCopyWithImpl<$Res>
    implements $LearnerAssignmentCopyWith<$Res> {
  _$LearnerAssignmentCopyWithImpl(this._self, this._then);

  final LearnerAssignment _self;
  final $Res Function(LearnerAssignment) _then;

/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assignment = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? lessonId = freezed,Object? state = null,Object? dueAt = freezed,Object? submission = freezed,Object? draft = freezed,}) {
  return _then(_self.copyWith(
assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as CourseAssignment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,lessonId: freezed == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AssignmentState,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,submission: freezed == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as Submission?,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as AssignmentWork?,
  ));
}
/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseAssignmentCopyWith<$Res> get assignment {
  
  return $CourseAssignmentCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubmissionCopyWith<$Res>? get submission {
    if (_self.submission == null) {
    return null;
  }

  return $SubmissionCopyWith<$Res>(_self.submission!, (value) {
    return _then(_self.copyWith(submission: value));
  });
}/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignmentWorkCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $AssignmentWorkCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [LearnerAssignment].
extension LearnerAssignmentPatterns on LearnerAssignment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerAssignment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerAssignment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerAssignment value)  $default,){
final _that = this;
switch (_that) {
case _LearnerAssignment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerAssignment value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerAssignment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  String? lessonId, @JsonKey(unknownEnumValue: AssignmentState.unknown)  AssignmentState state, @NullableUtcDateTimeConverter()  DateTime? dueAt,  Submission? submission,  AssignmentWork? draft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerAssignment() when $default != null:
return $default(_that.assignment,_that.courseTitle,_that.chapterTitle,_that.lessonId,_that.state,_that.dueAt,_that.submission,_that.draft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  String? lessonId, @JsonKey(unknownEnumValue: AssignmentState.unknown)  AssignmentState state, @NullableUtcDateTimeConverter()  DateTime? dueAt,  Submission? submission,  AssignmentWork? draft)  $default,) {final _that = this;
switch (_that) {
case _LearnerAssignment():
return $default(_that.assignment,_that.courseTitle,_that.chapterTitle,_that.lessonId,_that.state,_that.dueAt,_that.submission,_that.draft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  String? lessonId, @JsonKey(unknownEnumValue: AssignmentState.unknown)  AssignmentState state, @NullableUtcDateTimeConverter()  DateTime? dueAt,  Submission? submission,  AssignmentWork? draft)?  $default,) {final _that = this;
switch (_that) {
case _LearnerAssignment() when $default != null:
return $default(_that.assignment,_that.courseTitle,_that.chapterTitle,_that.lessonId,_that.state,_that.dueAt,_that.submission,_that.draft);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerAssignment extends LearnerAssignment {
  const _LearnerAssignment({required this.assignment, this.courseTitle = '', this.chapterTitle, this.lessonId, @JsonKey(unknownEnumValue: AssignmentState.unknown) this.state = AssignmentState.unknown, @NullableUtcDateTimeConverter() this.dueAt, this.submission, this.draft}): super._();
  factory _LearnerAssignment.fromJson(Map<String, dynamic> json) => _$LearnerAssignmentFromJson(json);

@override final  CourseAssignment assignment;
@override@JsonKey() final  String courseTitle;
@override final  String? chapterTitle;
@override final  String? lessonId;
@override@JsonKey(unknownEnumValue: AssignmentState.unknown) final  AssignmentState state;
/// When it is due **for this learner** — the server works a relative deadline out from when
/// their chapter opened.
@override@NullableUtcDateTimeConverter() final  DateTime? dueAt;
@override final  Submission? submission;
@override final  AssignmentWork? draft;

/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerAssignmentCopyWith<_LearnerAssignment> get copyWith => __$LearnerAssignmentCopyWithImpl<_LearnerAssignment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerAssignmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerAssignment&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.state, state) || other.state == state)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.submission, submission) || other.submission == submission)&&(identical(other.draft, draft) || other.draft == draft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignment,courseTitle,chapterTitle,lessonId,state,dueAt,submission,draft);

@override
String toString() {
  return 'LearnerAssignment(assignment: $assignment, courseTitle: $courseTitle, chapterTitle: $chapterTitle, lessonId: $lessonId, state: $state, dueAt: $dueAt, submission: $submission, draft: $draft)';
}


}

/// @nodoc
abstract mixin class _$LearnerAssignmentCopyWith<$Res> implements $LearnerAssignmentCopyWith<$Res> {
  factory _$LearnerAssignmentCopyWith(_LearnerAssignment value, $Res Function(_LearnerAssignment) _then) = __$LearnerAssignmentCopyWithImpl;
@override @useResult
$Res call({
 CourseAssignment assignment, String courseTitle, String? chapterTitle, String? lessonId,@JsonKey(unknownEnumValue: AssignmentState.unknown) AssignmentState state,@NullableUtcDateTimeConverter() DateTime? dueAt, Submission? submission, AssignmentWork? draft
});


@override $CourseAssignmentCopyWith<$Res> get assignment;@override $SubmissionCopyWith<$Res>? get submission;@override $AssignmentWorkCopyWith<$Res>? get draft;

}
/// @nodoc
class __$LearnerAssignmentCopyWithImpl<$Res>
    implements _$LearnerAssignmentCopyWith<$Res> {
  __$LearnerAssignmentCopyWithImpl(this._self, this._then);

  final _LearnerAssignment _self;
  final $Res Function(_LearnerAssignment) _then;

/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assignment = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? lessonId = freezed,Object? state = null,Object? dueAt = freezed,Object? submission = freezed,Object? draft = freezed,}) {
  return _then(_LearnerAssignment(
assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as CourseAssignment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,lessonId: freezed == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AssignmentState,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,submission: freezed == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as Submission?,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as AssignmentWork?,
  ));
}

/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseAssignmentCopyWith<$Res> get assignment {
  
  return $CourseAssignmentCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubmissionCopyWith<$Res>? get submission {
    if (_self.submission == null) {
    return null;
  }

  return $SubmissionCopyWith<$Res>(_self.submission!, (value) {
    return _then(_self.copyWith(submission: value));
  });
}/// Create a copy of LearnerAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignmentWorkCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $AssignmentWorkCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

// dart format on
