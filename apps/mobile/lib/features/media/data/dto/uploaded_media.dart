import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/media/media_rules.dart';

part 'uploaded_media.freezed.dart';
part 'uploaded_media.g.dart';

/// What `POST /media/upload` returns (`apps/api/src/routes/media.ts` `toMediaFile`) — the same
/// shape lesson content and assignment attachments carry as `MediaFile`.
@freezed
abstract class UploadedMedia with _$UploadedMedia {
  const factory UploadedMedia({
    required String id,

    /// The original file name, as the server stored it.
    required String name,

    /// Size in megabytes, rounded by the server to one decimal.
    required double sizeMb,

    /// Always `/media/<id>` — relative to the API, never an absolute URL.
    required String url,
    String? mime,
    @JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson)
    @Default(MediaKind.unknown)
    MediaKind kind,
  }) = _UploadedMedia;

  factory UploadedMedia.fromJson(Map<String, dynamic> json) => _$UploadedMediaFromJson(json);
}

String _kindToJson(MediaKind kind) => kind.name;
