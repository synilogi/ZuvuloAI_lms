import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/cancellation.dart';
import 'package:syniastrolms_mobile/features/media/media.dart';

class _FakeMediaApi implements MediaApi {
  AppFailure? failure;
  bool cancelMidway = false;
  int uploads = 0;
  final progress = <double>[];

  @override
  Future<UploadedMedia> upload({
    required String filePath,
    required String fileName,
    String? mimeType,
    void Function(double progress)? onProgress,
    RequestCancellation? cancellation,
  }) async {
    uploads++;
    onProgress?.call(0.5);
    if (cancelMidway) {
      throw const ApiException(NetworkFailure(NetworkProblem.cancelled));
    }
    if (failure != null) throw ApiException(failure!);
    onProgress?.call(1);
    return UploadedMedia(
      id: 'media_$uploads',
      name: fileName,
      sizeMb: 0.1,
      url: '/media/media_$uploads',
      mime: mimeType,
      kind: MediaRules.classify(fileName: fileName, mimeType: mimeType)?.kind ?? MediaKind.unknown,
    );
  }

  @override
  Future<Uint8List> bytes(
    String mediaId, {
    void Function(double)? onProgress,
    RequestCancellation? cancellation,
  }) async => throw UnimplementedError();
}

/// The first bytes of each type the academy accepts.
List<int> signatureFor(String fileName) {
  final ext = fileName.toLowerCase().split('.').last;
  return switch (ext) {
    'pdf' => '%PDF-1.4'.codeUnits,
    'png' => const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
    'jpg' || 'jpeg' => const [0xff, 0xd8, 0xff],
    'webp' => [...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits],
    'mp4' || 'mov' => [0, 0, 0, 0x18, ...'ftyp'.codeUnits],
    'webm' => const [0x1a, 0x45, 0xdf, 0xa3],
    _ => const <int>[],
  };
}

void main() {
  late _FakeMediaApi api;
  late ProviderContainer container;
  late Directory temp;

  /// A file whose first bytes really are what its extension says — the server checks them, so a
  /// fixture that lies would only test the refusal (SAAS-023, `matchesSignature`).
  PickedMedia pick(String name, int bytes, {String? mime, bool realContents = true}) {
    final head = realContents ? signatureFor(name) : const <int>[];
    final body = [...head, ...List.filled((bytes - head.length).clamp(0, bytes), 1)];
    final file = File('${temp.path}/$name')..writeAsBytesSync(body);
    return pickedFromFile(file, mimeType: mime);
  }

  setUp(() {
    api = _FakeMediaApi();
    temp = Directory.systemTemp.createTempSync('upload_controller_test');
    container = ProviderContainer(overrides: [mediaApiProvider.overrideWithValue(api)]);
    addTearDown(() {
      container.dispose();
      temp.deleteSync(recursive: true);
    });
  });

  MediaUploadController controller() => container.read(mediaUploadControllerProvider.notifier);
  MediaUploadState state() => container.read(mediaUploadControllerProvider);

  group('the pre-check refuses before anything is sent', () {
    test('a type the academy does not accept', () async {
      final uploaded = await controller().uploadPicked(
        pick('notes.txt', 10, mime: 'text/plain'),
        uploaderIsStaff: true,
      );

      expect(uploaded, isNull);
      expect(state().rejection, MediaRejection.type);
      expect(state().picked, isNotNull, reason: 'the file is kept so it can be swapped');
      expect(api.uploads, 0);
    });

    test('video from a learner', () async {
      await controller().uploadPicked(
        pick('lesson.mp4', 10, mime: 'video/mp4'),
        uploaderIsStaff: false,
      );

      expect(state().rejection, MediaRejection.videoNeedsStaff);
      expect(api.uploads, 0);
    });

    test('a file over its limit', () async {
      await controller().uploadPicked(
        pick('chart.png', 6 * 1024 * 1024, mime: 'image/png'),
        uploaderIsStaff: false,
      );

      expect(state().rejection, MediaRejection.size);
      expect(api.uploads, 0);
    });
  });

  test('an accepted file is uploaded with progress and reports the stored media', () async {
    final uploaded = await controller().uploadPicked(
      pick('chart.pdf', 2048, mime: 'application/pdf'),
      uploaderIsStaff: false,
    );

    expect(uploaded?.id, 'media_1');
    expect(state().uploaded?.url, '/media/media_1');
    expect(state().isUploading, isFalse);
    expect(state().hasFailed, isFalse);
  });

  test('a refusal from the server keeps the file so it can be retried', () async {
    api.failure = const PayloadTooLargeFailure(message: 'Documents can be at most 25 MB.');
    final picked = pick('chart.pdf', 2048, mime: 'application/pdf');

    await controller().uploadPicked(picked, uploaderIsStaff: false);
    expect(state().failure, isA<PayloadTooLargeFailure>());
    expect(state().picked?.name, 'chart.pdf');

    api.failure = null;
    final uploaded = await controller().retry(uploaderIsStaff: false);

    expect(uploaded, isNotNull);
    expect(state().hasFailed, isFalse);
    expect(api.uploads, 2);
  });

  test('cancelling leaves the picked file and is not reported as a failure', () async {
    api.cancelMidway = true;

    await controller().uploadPicked(
      pick('chart.pdf', 2048, mime: 'application/pdf'),
      uploaderIsStaff: false,
    );

    expect(state().hasFailed, isFalse);
    expect(state().isUploading, isFalse);
    expect(state().picked, isNotNull);
  });

  test('clear forgets the file', () async {
    await controller().uploadPicked(
      pick('chart.pdf', 2048, mime: 'application/pdf'),
      uploaderIsStaff: false,
    );

    controller().clear();

    expect(state().picked, isNull);
    expect(state().uploaded, isNull);
  });

  test('a cancelled picker does nothing', () async {
    final uploaded = await controller().pickAndUpload(
      uploaderIsStaff: false,
      picker: () async => <PlatformFile>[],
    );

    expect(uploaded, isNull);
    expect(state().picked, isNull);
    expect(api.uploads, 0);
  });
}
