// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Attachment _$AttachmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Attachment', json, ($checkedConvert) {
      final val = _Attachment(
        id: $checkedConvert('id', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        sizeMb: $checkedConvert('sizeMb', (v) => (v as num?)?.toDouble() ?? 0),
        url: $checkedConvert('url', (v) => v as String?),
        mime: $checkedConvert('mime', (v) => v as String?),
        pages: $checkedConvert('pages', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AttachmentToJson(_Attachment instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sizeMb': instance.sizeMb,
  'url': instance.url,
  'mime': instance.mime,
  'pages': instance.pages,
};

_RubricCriterion _$RubricCriterionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RubricCriterion', json, ($checkedConvert) {
      final val = _RubricCriterion(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        description: $checkedConvert('description', (v) => v as String? ?? ''),
        points: $checkedConvert('points', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$RubricCriterionToJson(_RubricCriterion instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'points': instance.points,
};

_DuePolicy _$DuePolicyFromJson(Map<String, dynamic> json) => $checkedCreate('_DuePolicy', json, (
  $checkedConvert,
) {
  final val = _DuePolicy(
    kind: $checkedConvert(
      'kind',
      (v) =>
          $enumDecodeNullable(_$DueKindEnumMap, v, unknownValue: DueKind.unknown) ?? DueKind.none,
    ),
    dueAt: $checkedConvert(
      'dueAt',
      (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
    ),
    days: $checkedConvert('days', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$DuePolicyToJson(_DuePolicy instance) => <String, dynamic>{
  'kind': _$DueKindEnumMap[instance.kind]!,
  'dueAt': const NullableUtcDateTimeConverter().toJson(instance.dueAt),
  'days': instance.days,
};

const _$DueKindEnumMap = {
  DueKind.date: 'date',
  DueKind.relative: 'relative',
  DueKind.none: 'none',
  DueKind.unknown: 'unknown',
};

_BirthDetails _$BirthDetailsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_BirthDetails', json, ($checkedConvert) {
      final val = _BirthDetails(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        date: $checkedConvert('date', (v) => v as String? ?? ''),
        time: $checkedConvert('time', (v) => v as String? ?? ''),
        place: $checkedConvert('place', (v) => v as String? ?? ''),
        lagna: $checkedConvert('lagna', (v) => v as String? ?? ''),
        moonSign: $checkedConvert('moonSign', (v) => v as String? ?? ''),
        nakshatra: $checkedConvert('nakshatra', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$BirthDetailsToJson(_BirthDetails instance) => <String, dynamic>{
  'label': instance.label,
  'date': instance.date,
  'time': instance.time,
  'place': instance.place,
  'lagna': instance.lagna,
  'moonSign': instance.moonSign,
  'nakshatra': instance.nakshatra,
};

_Review _$ReviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Review', json, ($checkedConvert) {
      final val = _Review(
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$ReviewStatusEnumMap, v, unknownValue: ReviewStatus.unknown) ??
              ReviewStatus.waiting,
        ),
        scores: $checkedConvert(
          'scores',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as num)) ??
              const <String, num>{},
        ),
        points: $checkedConvert('points', (v) => v as num?),
        score: $checkedConvert('score', (v) => v as num?),
        feedback: $checkedConvert('feedback', (v) => v as String? ?? ''),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReviewToJson(_Review instance) => <String, dynamic>{
  'status': _$ReviewStatusEnumMap[instance.status]!,
  'scores': instance.scores,
  'points': instance.points,
  'score': instance.score,
  'feedback': instance.feedback,
  'updatedAt': const NullableUtcDateTimeConverter().toJson(instance.updatedAt),
};

const _$ReviewStatusEnumMap = {
  ReviewStatus.waiting: 'waiting',
  ReviewStatus.inReview: 'in-review',
  ReviewStatus.graded: 'graded',
  ReviewStatus.returned: 'returned',
  ReviewStatus.unknown: 'unknown',
};

_Submission _$SubmissionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Submission', json, ($checkedConvert) {
      final val = _Submission(
        id: $checkedConvert('id', (v) => v as String),
        attempt: $checkedConvert('attempt', (v) => (v as num?)?.toInt() ?? 1),
        submittedAt: $checkedConvert(
          'submittedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        late: $checkedConvert('late', (v) => v as bool? ?? false),
        text: $checkedConvert('text', (v) => v as String?),
        files: $checkedConvert(
          'files',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <Attachment>[],
        ),
        chart: $checkedConvert(
          'chart',
          (v) => v == null ? null : BirthDetails.fromJson(v as Map<String, dynamic>),
        ),
        review: $checkedConvert(
          'review',
          (v) => v == null ? const Review() : Review.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SubmissionToJson(_Submission instance) => <String, dynamic>{
  'id': instance.id,
  'attempt': instance.attempt,
  'submittedAt': const UtcDateTimeConverter().toJson(instance.submittedAt),
  'late': instance.late,
  'text': instance.text,
  'files': instance.files.map((e) => e.toJson()).toList(),
  'chart': instance.chart?.toJson(),
  'review': instance.review.toJson(),
};

_CourseAssignment _$CourseAssignmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseAssignment', json, ($checkedConvert) {
      final val = _CourseAssignment(
        id: $checkedConvert('id', (v) => v as String),
        courseId: $checkedConvert('courseId', (v) => v as String),
        chapterId: $checkedConvert('chapterId', (v) => v as String?),
        lessonId: $checkedConvert('lessonId', (v) => v as String?),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        instructions: $checkedConvert('instructions', (v) => v as String? ?? ''),
        attachments: $checkedConvert(
          'attachments',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <Attachment>[],
        ),
        format: $checkedConvert(
          'format',
          (v) =>
              $enumDecodeNullable(
                _$SubmissionFormatEnumMap,
                v,
                unknownValue: SubmissionFormat.unknown,
              ) ??
              SubmissionFormat.unknown,
        ),
        wordLimit: $checkedConvert('wordLimit', (v) => (v as num?)?.toInt()),
        due: $checkedConvert(
          'due',
          (v) => v == null ? const DuePolicy() : DuePolicy.fromJson(v as Map<String, dynamic>),
        ),
        acceptsLate: $checkedConvert('acceptsLate', (v) => v as bool? ?? false),
        latePenalty: $checkedConvert('latePenalty', (v) => (v as num?)?.toInt() ?? 0),
        rubric: $checkedConvert(
          'rubric',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => RubricCriterion.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <RubricCriterion>[],
        ),
        maxScore: $checkedConvert('maxScore', (v) => (v as num?)?.toInt() ?? 0),
        passMark: $checkedConvert('passMark', (v) => (v as num?)?.toInt() ?? 0),
        status: $checkedConvert('status', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CourseAssignmentToJson(_CourseAssignment instance) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'chapterId': instance.chapterId,
  'lessonId': instance.lessonId,
  'title': instance.title,
  'instructions': instance.instructions,
  'attachments': instance.attachments.map((e) => e.toJson()).toList(),
  'format': _$SubmissionFormatEnumMap[instance.format]!,
  'wordLimit': instance.wordLimit,
  'due': instance.due.toJson(),
  'acceptsLate': instance.acceptsLate,
  'latePenalty': instance.latePenalty,
  'rubric': instance.rubric.map((e) => e.toJson()).toList(),
  'maxScore': instance.maxScore,
  'passMark': instance.passMark,
  'status': instance.status,
};

const _$SubmissionFormatEnumMap = {
  SubmissionFormat.file: 'file',
  SubmissionFormat.text: 'text',
  SubmissionFormat.chart: 'chart',
  SubmissionFormat.unknown: 'unknown',
};
