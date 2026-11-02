// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UserProfile', json, ($checkedConvert) {
      final val = _UserProfile(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$UserRoleEnumMap, v, unknownValue: UserRole.unknown),
        ),
        descriptor: $checkedConvert('descriptor', (v) => v as String),
        instructorId: $checkedConvert('instructorId', (v) => v as String?),
        permissions: $checkedConvert(
          'permissions',
          (v) => v == null ? const [] : const PermissionKeysConverter().fromJson(v as List?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'role': _$UserRoleEnumMap[instance.role]!,
  'descriptor': instance.descriptor,
  'instructorId': instance.instructorId,
  'permissions': const PermissionKeysConverter().toJson(instance.permissions),
};

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.instructor: 'instructor',
  UserRole.admin: 'admin',
  UserRole.superadmin: 'superadmin',
  UserRole.unknown: 'unknown',
};
