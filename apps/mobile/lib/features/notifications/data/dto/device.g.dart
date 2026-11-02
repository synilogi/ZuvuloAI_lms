// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegisteredDevice _$RegisteredDeviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RegisteredDevice', json, ($checkedConvert) {
      final val = _RegisteredDevice(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        platform: $checkedConvert('platform', (v) => v as String? ?? ''),
        tokenEnd: $checkedConvert('tokenEnd', (v) => v as String? ?? ''),
        current: $checkedConvert('current', (v) => v as bool? ?? false),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        lastSeenAt: $checkedConvert(
          'lastSeenAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RegisteredDeviceToJson(_RegisteredDevice instance) => <String, dynamic>{
  'id': instance.id,
  'platform': instance.platform,
  'tokenEnd': instance.tokenEnd,
  'current': instance.current,
  'createdAt': const UtcDateTimeConverter().toJson(instance.createdAt),
  'lastSeenAt': const UtcDateTimeConverter().toJson(instance.lastSeenAt),
};
