import 'package:freezed_annotation/freezed_annotation.dart';

part 'level.freezed.dart';
part 'level.g.dart';

/// A course level, from `GET /catalog/levels` (`packages/domain/src/catalog.ts` `Level`).
/// Only the fields the backend returns are modelled (§10.4).
@freezed
abstract class Level with _$Level {
  const factory Level({
    required String id,
    required String name,

    /// 1-based position in the progression.
    required int order,
    String? summary,
  }) = _Level;

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
}
