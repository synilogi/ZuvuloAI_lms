import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/media/media_url_resolver.dart';

void main() {
  // Production mounts the API under /api; dev is a bare host and port.
  final production = MediaUrlResolver(Uri.parse('https://academy.example/api'));
  final dev = MediaUrlResolver(Uri.parse('http://10.0.2.2:4100'));

  test('a stored path becomes a URL on the API, keeping the /api mount', () {
    expect(production.resolve('/media/m1').toString(), 'https://academy.example/api/media/m1');
    expect(dev.resolve('/media/m1').toString(), 'http://10.0.2.2:4100/media/m1');
  });

  test('an absolute URL on the API host is accepted', () {
    expect(
      production.resolve('https://academy.example/api/media/m1').toString(),
      'https://academy.example/api/media/m1',
    );
  });

  group('the bearer never goes anywhere else', () {
    const elsewhere = [
      'https://evil.example/media/m1',
      'http://academy.example/api/media/m1', // same host, wrong scheme
      'https://academy.example:8443/api/media/m1', // same host, wrong port
      '//evil.example/media/m1',
      'file:///etc/passwd',
      '',
    ];

    for (final url in elsewhere) {
      test('"$url" is refused', () {
        expect(production.resolve(url), isNull);
        expect(production.isOurs(url), isFalse);
      });
    }

    test('null is refused', () {
      expect(production.resolve(null), isNull);
      expect(production.isOurs(null), isFalse);
    });
  });
}
