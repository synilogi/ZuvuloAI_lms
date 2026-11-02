// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Level _$LevelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Level', json, ($checkedConvert) {
      final val = _Level(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        order: $checkedConvert('order', (v) => (v as num).toInt()),
        summary: $checkedConvert('summary', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LevelToJson(_Level instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'order': instance.order,
  'summary': instance.summary,
};
