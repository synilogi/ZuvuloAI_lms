// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Rank _$RankFromJson(Map<String, dynamic> json) => $checkedCreate('_Rank', json, ($checkedConvert) {
  final val = _Rank(
    id: $checkedConvert('id', (v) => v as String? ?? ''),
    title: $checkedConvert('title', (v) => v as String? ?? ''),
    order: $checkedConvert('order', (v) => (v as num?)?.toInt() ?? 0),
    descriptor: $checkedConvert('descriptor', (v) => v as String? ?? ''),
    criteria: $checkedConvert(
      'criteria',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => CertificateCriterion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CertificateCriterion>[],
    ),
  );
  return val;
});

Map<String, dynamic> _$RankToJson(_Rank instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'order': instance.order,
  'descriptor': instance.descriptor,
  'criteria': instance.criteria.map((e) => e.toJson()).toList(),
};

_RankStanding _$RankStandingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RankStanding', json, ($checkedConvert) {
      final val = _RankStanding(
        rankId: $checkedConvert('rankId', (v) => v as String? ?? ''),
        achieved: $checkedConvert(
          'achieved',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)) ??
              const <String, String>{},
        ),
        progress: $checkedConvert(
          'progress',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as num)) ??
              const <String, num>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$RankStandingToJson(_RankStanding instance) => <String, dynamic>{
  'rankId': instance.rankId,
  'achieved': instance.achieved,
  'progress': instance.progress,
};

_RankLadder _$RankLadderFromJson(Map<String, dynamic> json) => $checkedCreate('_RankLadder', json, (
  $checkedConvert,
) {
  final val = _RankLadder(
    ranks: $checkedConvert(
      'ranks',
      (v) =>
          (v as List<dynamic>?)?.map((e) => Rank.fromJson(e as Map<String, dynamic>)).toList() ??
          const <Rank>[],
    ),
    standing: $checkedConvert(
      'standing',
      (v) => v == null ? const RankStanding() : RankStanding.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$RankLadderToJson(_RankLadder instance) => <String, dynamic>{
  'ranks': instance.ranks.map((e) => e.toJson()).toList(),
  'standing': instance.standing.toJson(),
};
