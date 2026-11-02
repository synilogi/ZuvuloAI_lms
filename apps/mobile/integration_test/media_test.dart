import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/media/media_rules.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/media/data/media_api.dart';

/// Media against the **real** API on the scratch database (`tool/contract_server.sh start`).
const _password = 'syniastrolms123';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  late Directory temp;

  setUpAll(() {
    config = AppConfig.fromEnvironment(Flavor.dev);
    temp = Directory.systemTemp.createTempSync('media_integration');
  });

  tearDownAll(() => temp.deleteSync(recursive: true));

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  Future<_Token> signIn(String email) async {
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return store;
  }

  File fileOf(String name, List<int> bytes) => File('${temp.path}/$name')..writeAsBytesSync(bytes);

  /// The server checks a file's first bytes against its extension (SAAS-023), so a fixture has to
  /// start the way the real format does.
  List<int> bodyFor(String name, int length, {int fill = 7}) {
    final head = switch (name.split('.').last) {
      'pdf' => '%PDF-1.4'.codeUnits,
      'mp4' || 'mov' => [0, 0, 0, 0x18, ...'ftyp'.codeUnits],
      'webm' => const [0x1a, 0x45, 0xdf, 0xa3],
      _ => const <int>[],
    };
    return [...head, ...List.filled((length - head.length).clamp(0, length), fill)];
  }

  testWidgets('a learner uploads an image and reads it back', (tester) async {
    final learner = await signIn('ananya@syniastrolms.test');
    final api = MediaApi(clientFor(learner));
    // A tiny PNG — the server checks the type and extension, not the pixels.
    final png = fileOf(
      'chart.png',
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );

    final uploaded = await api.upload(
      filePath: png.path,
      fileName: 'chart.png',
      mimeType: 'image/png',
    );

    expect(uploaded.kind, MediaKind.image);
    expect(uploaded.url, '/media/${uploaded.id}');

    final bytes = await api.bytes(uploaded.id);
    expect(bytes, isNotEmpty);
  });

  testWidgets('a learner may not upload video — the server says so', (tester) async {
    final learner = await signIn('ananya@syniastrolms.test');
    final api = MediaApi(clientFor(learner));
    final video = fileOf('lesson.mp4', bodyFor('lesson.mp4', 1024, fill: 0));

    await expectLater(
      api.upload(filePath: video.path, fileName: 'lesson.mp4', mimeType: 'video/mp4'),
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
  });

  testWidgets('a learner cannot read another learner\'s upload (404, not 403)', (tester) async {
    final asha = await signIn('ananya@syniastrolms.test');
    final rohit = await signIn('rohit@syniastrolms.test');
    final uploaded = await MediaApi(clientFor(asha)).upload(
      filePath: fileOf('private.pdf', bodyFor('private.pdf', 64)).path,
      fileName: 'private.pdf',
      mimeType: 'application/pdf',
    );

    await expectLater(
      MediaApi(clientFor(rohit)).bytes(uploaded.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('a staff upload nobody has placed in a lesson is not course material', (
    tester,
  ) async {
    // SAAS-023 narrowed reading: staff having uploaded a file is not by itself a reason for a
    // learner to see it. It has to be somewhere they may open.
    final instructor = await signIn('meenakshi@syniastrolms.test');
    final learner = await signIn('ananya@syniastrolms.test');
    final uploaded = await MediaApi(clientFor(instructor)).upload(
      filePath: fileOf('loose.mp4', bodyFor('loose.mp4', 512)).path,
      fileName: 'loose.mp4',
      mimeType: 'video/mp4',
    );

    await expectLater(
      MediaApi(clientFor(learner)).bytes(uploaded.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('a video placed in a free-preview lesson streams, and serves ranges', (tester) async {
    final instructor = await signIn('meenakshi@syniastrolms.test');
    final learner = await signIn('ananya@syniastrolms.test');
    final staffClient = clientFor(instructor);

    // A real ISO box header, then a known pattern the range request can be checked against.
    final payload = [...bodyFor('lesson.mp4', 8), ...List<int>.generate(2040, (i) => i % 251)];
    final uploaded = await MediaApi(staffClient).upload(
      filePath: fileOf('lesson.mp4', payload).path,
      fileName: 'lesson.mp4',
      mimeType: 'video/mp4',
    );

    // Put it where a learner may open it: the seeded course's published free-preview lesson.
    final course =
        (await clientFor(_Token()).get('/catalog/courses/maths-foundations'))!
            as Map<String, dynamic>;
    final lesson =
        ((course['chapters']! as List).first as Map<String, dynamic>)['lessons']! as List<dynamic>;
    final preview = lesson.cast<Map<String, dynamic>>().firstWhere(
      (l) => l['type'] == 'video' && l['isPreview'] == true,
    );
    final before = preview['content'];
    Future<void> setContent(Object? content) => staffClient.patch(
      '/courses/${course['id']}/lessons/${preview['id']}',
      body: {'content': content ?? <String, Object?>{}},
    );
    await setContent({
      'video': {
        'file': {
          'id': uploaded.id,
          'name': uploaded.name,
          'sizeMb': uploaded.sizeMb,
          'url': uploaded.url,
          'mime': uploaded.mime,
        },
        'durationSec': 1080,
        'captions': true,
        'markers': <Object>[],
      },
    });
    addTearDown(() => setContent(before));

    expect(await MediaApi(clientFor(learner)).bytes(uploaded.id), hasLength(2048));

    // The player seeks with Range requests; the server answers 206 with just that slice.
    final request = await HttpClient().getUrl(
      Uri.parse('${config.apiBaseUrl}/media/${uploaded.id}'),
    );
    request.headers
      ..add('Authorization', 'Bearer ${learner.token}')
      ..add('Range', 'bytes=100-199');
    final response = await request.close();
    final slice = await response.fold<List<int>>([], (all, chunk) => all..addAll(chunk));

    expect(response.statusCode, 206, reason: 'range requests are what seeking depends on');
    expect(slice, hasLength(100));
    expect(slice, payload.sublist(100, 200));
  });

  testWidgets('an unauthenticated read is refused', (tester) async {
    final anonymous = MediaApi(clientFor(_Token()));

    await expectLater(
      anonymous.bytes('anything'),
      throwsA(
        isA<ApiException>().having((e) => e.failure, 'failure', isA<UnauthenticatedFailure>()),
      ),
    );
  });
}
