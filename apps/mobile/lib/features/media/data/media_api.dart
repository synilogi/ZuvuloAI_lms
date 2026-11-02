import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/cancellation.dart';
import '../../../core/network/json.dart';
import 'dto/uploaded_media.dart';

/// `apps/api/src/routes/media.ts`: one multipart field named `file`, and an authenticated byte
/// stream for reading one back.
class MediaApi {
  MediaApi(this._client);

  final ApiClient _client;

  Future<UploadedMedia> upload({
    required String filePath,
    required String fileName,
    String? mimeType,
    void Function(double progress)? onProgress,
    RequestCancellation? cancellation,
  }) async {
    const endpoint = 'POST /media/upload';
    final body = await _client.upload(
      '/media/upload',
      file: await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: mimeType == null ? null : DioMediaType.parse(mimeType),
      ),
      onProgress: onProgress,
      cancelToken: cancellation?.token,
    );
    return UploadedMedia.fromJson(asJsonObject(endpoint, body));
  }

  /// The bytes of a stored file. The server refuses with 404 when the caller may not read it.
  /// `async` so a refused id comes back as a failed future like any other failure, never as a
  /// synchronous throw.
  Future<Uint8List> bytes(
    String mediaId, {
    void Function(double progress)? onProgress,
    RequestCancellation? cancellation,
  }) async => _client.downloadBytes(
    ApiPath.of(['media', ApiPath.id(mediaId)]),
    onProgress: onProgress,
    cancelToken: cancellation?.token,
  );
}

final mediaApiProvider = Provider<MediaApi>((ref) => MediaApi(ref.watch(apiClientProvider)));
