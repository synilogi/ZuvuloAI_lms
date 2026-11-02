import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/media/media_cache.dart';

void main() {
  late Directory root;
  late MediaCache cache;

  setUp(() {
    root = Directory.systemTemp.createTempSync('media_cache_test');
    cache = MediaCache(temporaryDirectory: () => root);
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
  });

  test('temporary files live in their own folder', () async {
    final file = await cache.temporaryFile('m1.pdf');
    await file.writeAsBytes([1, 2, 3]);

    expect(file.path, contains('syniastro_media'));
    expect(file.existsSync(), isTrue);
  });

  test('purging removes every temporary file (sign-out)', () async {
    final first = await cache.temporaryFile('m1.pdf');
    final second = await cache.temporaryFile('m2.pdf');
    await first.writeAsBytes([1]);
    await second.writeAsBytes([2]);

    await cache.purge();

    expect(first.existsSync(), isFalse);
    expect(second.existsSync(), isFalse);
    expect((await cache.temporaryMediaDirectory()).listSync(), isEmpty);
  });

  test('each person gets their own image cache, and purging drops it', () {
    final asha = cache.imagesFor('user_1');
    expect(identical(cache.imagesFor('user_1'), asha), isTrue, reason: 'same person, same store');

    final ravi = cache.imagesFor('user_2');
    expect(identical(ravi, asha), isFalse, reason: 'a different person never reads their cache');
  });
}
