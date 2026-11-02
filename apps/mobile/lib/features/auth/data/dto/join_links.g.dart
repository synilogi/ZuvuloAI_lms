// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_links.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LmsSummary _$LmsSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LmsSummary', json, ($checkedConvert) {
      final val = _LmsSummary(
        name: $checkedConvert('name', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LmsSummaryToJson(_LmsSummary instance) => <String, dynamic>{
  'name': instance.name,
  'slug': instance.slug,
};

_LmsJoinPage _$LmsJoinPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LmsJoinPage', json, ($checkedConvert) {
      final val = _LmsJoinPage(
        name: $checkedConvert('name', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        open: $checkedConvert('open', (v) => v as bool? ?? false),
        invitationOnly: $checkedConvert('invitationOnly', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LmsJoinPageToJson(_LmsJoinPage instance) => <String, dynamic>{
  'name': instance.name,
  'slug': instance.slug,
  'open': instance.open,
  'invitationOnly': instance.invitationOnly,
};

_InvitationView _$InvitationViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InvitationView', json, ($checkedConvert) {
      final val = _InvitationView(
        lms: $checkedConvert('lms', (v) => LmsSummary.fromJson(v as Map<String, dynamic>)),
        role: $checkedConvert('role', (v) => v as String? ?? 'student'),
        email: $checkedConvert('email', (v) => v as String?),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        open: $checkedConvert('open', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$InvitationViewToJson(_InvitationView instance) => <String, dynamic>{
  'lms': instance.lms.toJson(),
  'role': instance.role,
  'email': instance.email,
  'expiresAt': const UtcDateTimeConverter().toJson(instance.expiresAt),
  'open': instance.open,
};

_CourseLinkCourse _$CourseLinkCourseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseLinkCourse', json, ($checkedConvert) {
      final val = _CourseLinkCourse(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CourseLinkCourseToJson(_CourseLinkCourse instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
};

_CourseLinkView _$CourseLinkViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseLinkView', json, ($checkedConvert) {
      final val = _CourseLinkView(
        lms: $checkedConvert('lms', (v) => LmsSummary.fromJson(v as Map<String, dynamic>)),
        course: $checkedConvert(
          'course',
          (v) => CourseLinkCourse.fromJson(v as Map<String, dynamic>),
        ),
        open: $checkedConvert('open', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$CourseLinkViewToJson(_CourseLinkView instance) => <String, dynamic>{
  'lms': instance.lms.toJson(),
  'course': instance.course.toJson(),
  'open': instance.open,
};
