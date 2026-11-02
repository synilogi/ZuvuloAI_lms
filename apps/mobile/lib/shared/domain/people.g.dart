// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'people.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Student _$StudentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Student', json, ($checkedConvert) {
      final val = _Student(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String? ?? ''),
        phone: $checkedConvert('phone', (v) => v as String?),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        joinedAt: $checkedConvert(
          'joinedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        lastActiveAt: $checkedConvert(
          'lastActiveAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        suspended: $checkedConvert('suspended', (v) => v as bool?),
        rankId: $checkedConvert('rankId', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$StudentToJson(_Student instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'city': instance.city,
  'joinedAt': const NullableUtcDateTimeConverter().toJson(instance.joinedAt),
  'lastActiveAt': const NullableUtcDateTimeConverter().toJson(instance.lastActiveAt),
  'suspended': instance.suspended,
  'rankId': instance.rankId,
};

_Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Enrollment', json, ($checkedConvert) {
      final val = _Enrollment(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        studentId: $checkedConvert('studentId', (v) => v as String? ?? ''),
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        enrolledAt: $checkedConvert(
          'enrolledAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$EnrollmentStatusEnumMap,
                v,
                unknownValue: EnrollmentStatus.unknown,
              ) ??
              EnrollmentStatus.active,
        ),
        progress: $checkedConvert('progress', (v) => v as num? ?? 0),
        source: $checkedConvert(
          'source',
          (v) =>
              $enumDecodeNullable(
                _$EnrollmentSourceEnumMap,
                v,
                unknownValue: EnrollmentSource.unknown,
              ) ??
              EnrollmentSource.self,
        ),
        lastActiveAt: $checkedConvert(
          'lastActiveAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        completedAt: $checkedConvert(
          'completedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        lastLessonId: $checkedConvert('lastLessonId', (v) => v as String?),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EnrollmentToJson(_Enrollment instance) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'courseId': instance.courseId,
  'enrolledAt': const NullableUtcDateTimeConverter().toJson(instance.enrolledAt),
  'status': _$EnrollmentStatusEnumMap[instance.status]!,
  'progress': instance.progress,
  'source': _$EnrollmentSourceEnumMap[instance.source]!,
  'lastActiveAt': const NullableUtcDateTimeConverter().toJson(instance.lastActiveAt),
  'completedAt': const NullableUtcDateTimeConverter().toJson(instance.completedAt),
  'lastLessonId': instance.lastLessonId,
  'expiresAt': const NullableUtcDateTimeConverter().toJson(instance.expiresAt),
};

const _$EnrollmentStatusEnumMap = {
  EnrollmentStatus.active: 'active',
  EnrollmentStatus.completed: 'completed',
  EnrollmentStatus.paused: 'paused',
  EnrollmentStatus.expired: 'expired',
  EnrollmentStatus.unknown: 'unknown',
};

const _$EnrollmentSourceEnumMap = {
  EnrollmentSource.self: 'self',
  EnrollmentSource.admin: 'admin',
  EnrollmentSource.cohort: 'cohort',
  EnrollmentSource.scholarship: 'scholarship',
  EnrollmentSource.purchase: 'purchase',
  EnrollmentSource.unknown: 'unknown',
};
