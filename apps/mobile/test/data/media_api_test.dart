import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/media/media_rules.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/media/data/media_api.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late MediaApi api;
  late Directory temp;
  late File file;

  setUp(() {
    adapter = FakeAdapter();
    api = MediaApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
    temp = Directory.systemTemp.createTempSync('media_api_test');
    file = File('${temp.path}/chart.pdf')..writeAsBytesSync(List.filled(2048, 7));
    addTearDown(() => temp.deleteSync(recursive: true));
  });

  group('upload', () {
    test('sends one multipart field named file and reads the stored media back', () async {
      adapter.enqueueJson({
        'id': 'media_1',
        'name': 'chart.pdf',
        'sizeMb': 0.1,
        'url': '/media/media_1',
        'mime': 'application/pdf',
        'kind': 'document',
      }, status: 201);
      final progress = <double>[];

      final uploaded = await api.upload(
        filePath: file.path,
        fileName: 'chart.pdf',
        mimeType: 'application/pdf',
        onProgress: progress.add,
      );

      expect(adapter.lastRequest.path, '/media/upload');
      expect(adapter.lastRequest.method, 'POST');
      final form = adapter.lastRequest.data! as FormData;
      expect(form.files, hasLength(1));
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'chart.pdf');
      expect(form.files.single.value.contentType?.mimeType, 'application/pdf');
      expect(adapter.lastRequest.headers['Authorization'], 'Bearer jwt');
      expect(progress.last, 1.0);

      expect(uploaded.id, 'media_1');
      expect(uploaded.url, '/media/media_1');
      expect(uploaded.kind, MediaKind.document);
      expect(uploaded.sizeMb, 0.1);
    });

    test('a kind the build does not know does not break the response', () async {
      adapter.enqueueJson({
        'id': 'm2',
        'name': 'a.bin',
        'sizeMb': 1.0,
        'url': '/media/m2',
        'kind': 'audio',
      }, status: 201);

      final uploaded = await api.upload(filePath: file.path, fileName: 'a.bin');

      expect(uploaded.kind, MediaKind.unknown);
    });

    test('the server\'s refusals surface as typed failures', () async {
      adapter.enqueueStatus(
        403,
        body: {'message': 'Only instructors and academy admins can upload video.'},
      );
      await expectLater(
        api.upload(filePath: file.path, fileName: 'lesson.mp4', mimeType: 'video/mp4'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<ForbiddenFailure>().having(
              (f) => f.message,
              'message',
              'Only instructors and academy admins can upload video.',
            ),
          ),
        ),
      );

      adapter.enqueueStatus(413, body: {'message': 'Documents can be at most 25 MB.'});
      await expectLater(
        api.upload(filePath: file.path, fileName: 'chart.pdf', mimeType: 'application/pdf'),
        throwsA(
          isA<ApiException>().having((e) => e.failure, 'failure', isA<PayloadTooLargeFailure>()),
        ),
      );
    });
  });

  group('reading a file back', () {
    test('requests the encoded media path with the bearer and reports progress', () async {
      adapter.enqueue(
        (_) async => ResponseBody.fromBytes(
          List.filled(64, 1),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/pdf'],
          },
        ),
      );
      final progress = <double>[];

      final bytes = await api.bytes('media 1', onProgress: progress.add);

      expect(adapter.lastRequest.path, '/media/media%201');
      expect(adapter.lastRequest.headers['Authorization'], 'Bearer jwt');
      expect(bytes, hasLength(64));
    });

    test('a file the caller may not read is a 404, never "forbidden"', () async {
      adapter.enqueueStatus(404, body: {'message': 'File not found.'});

      await expectLater(
        api.bytes('media_1'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
      );
    });

    test('an id the path validator refuses never reaches the network', () async {
      await expectLater(api.bytes('..'), throwsA(isA<ApiException>()));
      expect(adapter.requests, isEmpty);
    });
  });
}
