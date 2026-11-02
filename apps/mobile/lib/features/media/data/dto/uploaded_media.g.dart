// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uploaded_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UploadedMedia _$UploadedMediaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UploadedMedia', json, ($checkedConvert) {
      final val = _UploadedMedia(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        sizeMb: $checkedConvert('sizeMb', (v) => (v as num).toDouble()),
        url: $checkedConvert('url', (v) => v as String),
        mime: $checkedConvert('mime', (v) => v as String?),
        kind: $checkedConvert('kind', (v) => v == null ? MediaKind.unknown : MediaKind.parse(v)),
      );
      return val;
    });

Map<String, dynamic> _$UploadedMediaToJson(_UploadedMedia instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sizeMb': instance.sizeMb,
  'url': instance.url,
  'mime': instance.mime,
  'kind': _kindToJson(instance.kind),
};
