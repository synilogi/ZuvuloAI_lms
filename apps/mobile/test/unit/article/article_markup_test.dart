import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

/// The article dialect mirrors the web's `ArticleBody.tsx`. Anything outside the dialect stays
/// plain text: an article body is content from the server and never markup the app executes.
void main() {
  group('blocks', () {
    test('splits on blank lines and recognises each block kind', () {
      final blocks = ArticleMarkup.blocks(
        '## Welcome\n\n'
        'A paragraph.\n\n'
        '> A quote\n> over two lines\n\n'
        '- one\n- two\n\n'
        '1. first\n2. second',
      );

      expect(blocks.map((b) => b.kind), [
        ArticleBlockKind.heading,
        ArticleBlockKind.paragraph,
        ArticleBlockKind.quote,
        ArticleBlockKind.bullets,
        ArticleBlockKind.numbers,
      ]);
      expect(blocks[0].lines.single, 'Welcome');
      expect(blocks[2].lines.single, 'A quote over two lines');
      expect(blocks[3].lines, ['one', 'two']);
      expect(blocks[4].lines, ['first', 'second']);
    });

    test('a list with one stray line is a paragraph, as on the web', () {
      final blocks = ArticleMarkup.blocks('- one\nnot an item');

      expect(blocks.single.kind, ArticleBlockKind.paragraph);
    });

    test('an empty body renders nothing', () {
      expect(ArticleMarkup.blocks('   \n\n  '), isEmpty);
    });
  });

  group('inline runs', () {
    test('bold, italic and plain text', () {
      final spans = ArticleMarkup.spans('Read **this** and _that_ now.');

      expect(spans.map((s) => s.text), ['Read ', 'this', ' and ', 'that', ' now.']);
      expect(spans[1].bold, isTrue);
      expect(spans[3].italic, isTrue);
      expect(spans[0].href, isNull);
    });

    test('an https link becomes a link', () {
      final spans = ArticleMarkup.spans('See [the guide](https://example.org/a).');

      expect(spans[1].text, 'the guide');
      expect(spans[1].href, 'https://example.org/a');
    });

    test('a link that is not absolute https stays literal text and is never tappable', () {
      for (final href in [
        'http://example.org',
        'javascript:alert(1)',
        '/local/path',
        'mailto:someone@example.test',
        'https:///no-host',
      ]) {
        final spans = ArticleMarkup.spans('Open [here]($href).');
        expect(spans.every((s) => s.href == null), isTrue, reason: href);
        expect(spans.map((s) => s.text).join(), 'Open [here]($href).');
      }
    });

    test('isSafeLink accepts only absolute https with a host', () {
      expect(ArticleMarkup.isSafeLink('https://example.org'), isTrue);
      expect(ArticleMarkup.isSafeLink('https://example.org/a?b=c'), isTrue);
      expect(ArticleMarkup.isSafeLink('http://example.org'), isFalse);
      expect(ArticleMarkup.isSafeLink('example.org'), isFalse);
      expect(ArticleMarkup.isSafeLink(''), isFalse);
    });

    test('markup the dialect does not know is shown as written', () {
      final spans = ArticleMarkup.spans('<script>alert(1)</script> & ![img](x)');

      expect(spans.map((s) => s.text).join(), '<script>alert(1)</script> & ![img](x)');
      expect(spans.every((s) => s.href == null && !s.bold && !s.italic), isTrue);
    });
  });
}
