// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AuthResponse', json, ($checkedConvert) {
      final val = _AuthResponse(
        token: $checkedConvert('token', (v) => v as String),
        user: $checkedConvert('user', (v) => UserProfile.fromJson(v as Map<String, dynamic>)),
      );
      return val;
    });

Map<String, dynamic> _$AuthResponseToJson(_AuthResponse instance) => <String, dynamic>{
  'token': instance.token,
  'user': instance.user.toJson(),
};
