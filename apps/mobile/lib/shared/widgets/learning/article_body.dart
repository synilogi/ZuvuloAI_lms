import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// One block of an article, as the editor's tiny markdown dialect writes it.
enum ArticleBlockKind { paragraph, heading, quote, bullets, numbers }

@immutable
class ArticleBlock {
  const ArticleBlock(this.kind, this.lines);

  final ArticleBlockKind kind;

  /// One entry per list item; a single entry for the other kinds.
  final List<String> lines;
}

/// An inline run: plain, bold, italic, or a link.
@immutable
class ArticleSpan {
  const ArticleSpan(this.text, {this.bold = false, this.italic = false, this.href});

  final String text;
  final bool bold;
  final bool italic;

  /// Absolute `https` target, or null — any other scheme is kept as plain text (§18).
  final String? href;
}

/// The article dialect the web's `ArticleBody.tsx` renders: `## heading`, `> quote`, `- item`,
/// `1. item`, `**bold**`, `_italic_`, `[label](https://…)` — and nothing else, so a body from the
/// server can never carry markup, script or a non-web scheme into the app (§25.2).
abstract final class ArticleMarkup {
  static final _inline = RegExp(r'(\*\*[^*]+\*\*|_[^_]+_|\[[^\]]+\]\([^)]+\))');
  static final _link = RegExp(r'^\[([^\]]+)\]\(([^)]+)\)$');
  static final _numbered = RegExp(r'^\d+\.\s');

  /// Splits [body] into blocks on blank lines, exactly as the web does.
  static List<ArticleBlock> blocks(String body) {
    final out = <ArticleBlock>[];
    for (final block in body.trim().split(RegExp(r'\n{2,}'))) {
      if (block.trim().isEmpty) continue;
      final lines = block.split('\n');
      if (block.startsWith('## ')) {
        out.add(ArticleBlock(ArticleBlockKind.heading, [block.substring(3)]));
      } else if (block.startsWith('> ')) {
        out.add(
          ArticleBlock(ArticleBlockKind.quote, [
            lines.map((l) => l.replaceFirst(RegExp(r'^>\s?'), '')).join(' '),
          ]),
        );
      } else if (lines.every((l) => l.startsWith('- '))) {
        out.add(ArticleBlock(ArticleBlockKind.bullets, [for (final l in lines) l.substring(2)]));
      } else if (lines.every(_numbered.hasMatch)) {
        out.add(
          ArticleBlock(ArticleBlockKind.numbers, [
            for (final l in lines) l.replaceFirst(_numbered, ''),
          ]),
        );
      } else {
        out.add(ArticleBlock(ArticleBlockKind.paragraph, [block]));
      }
    }
    return out;
  }

  /// Splits one line into its inline runs. A link whose target is not absolute `https` keeps its
  /// original text and is never tappable.
  static List<ArticleSpan> spans(String text) {
    final out = <ArticleSpan>[];
    var index = 0;
    for (final match in _inline.allMatches(text)) {
      if (match.start > index) out.add(ArticleSpan(text.substring(index, match.start)));
      final part = match.group(0)!;
      final link = _link.firstMatch(part);
      if (part.startsWith('**')) {
        out.add(ArticleSpan(part.substring(2, part.length - 2), bold: true));
      } else if (part.startsWith('_')) {
        out.add(ArticleSpan(part.substring(1, part.length - 1), italic: true));
      } else if (link != null) {
        final href = link.group(2)!;
        out.add(isSafeLink(href) ? ArticleSpan(link.group(1)!, href: href) : ArticleSpan(part));
      }
      index = match.end;
    }
    if (index < text.length) out.add(ArticleSpan(text.substring(index)));
    return out;
  }

  /// Only absolute `https` links leave the app (§18); anything else stays text.
  static bool isSafeLink(String href) {
    final uri = Uri.tryParse(href);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}

/// Renders an article body in the reading measure. [onOpenLink] receives a validated `https` URL.
class ArticleBody extends StatefulWidget {
  const ArticleBody({required this.body, super.key, this.onOpenLink});

  final String body;
  final void Function(Uri url)? onOpenLink;

  @override
  State<ArticleBody> createState() => _ArticleBodyState();
}

class _ArticleBodyState extends State<ArticleBody> {
  /// One recognizer per link, disposed with the widget (they hold a gesture arena entry).
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    final blocks = ArticleMarkup.blocks(widget.body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: Space.s4),
          _block(context, blocks[i]),
        ],
      ],
    );
  }

  Widget _block(BuildContext context, ArticleBlock block) {
    final c = context.colors;
    final type = context.type;
    switch (block.kind) {
      case ArticleBlockKind.heading:
        return Semantics(header: true, child: _line(context, block.lines.first, type.titleM));
      case ArticleBlockKind.quote:
        return Container(
          padding: const EdgeInsets.only(left: Space.s4),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.accent, width: 3)),
          ),
          child: _line(
            context,
            block.lines.first,
            type.bodyM.copyWith(color: c.muted, fontStyle: FontStyle.italic),
          ),
        );
      case ArticleBlockKind.bullets:
      case ArticleBlockKind.numbers:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < block.lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        block.kind == ArticleBlockKind.bullets ? '•' : '${i + 1}.',
                        style: type.bodyM.copyWith(color: c.muted),
                      ),
                    ),
                    Expanded(child: _line(context, block.lines[i], type.bodyM)),
                  ],
                ),
              ),
          ],
        );
      case ArticleBlockKind.paragraph:
        return _line(context, block.lines.first, type.bodyM);
    }
  }

  Widget _line(BuildContext context, String text, TextStyle style) {
    final c = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          for (final span in ArticleMarkup.spans(text))
            TextSpan(
              text: span.text,
              style: style.copyWith(
                fontWeight: span.bold ? FontWeight.w600 : null,
                fontStyle: span.italic ? FontStyle.italic : null,
                color: span.href == null ? null : c.accentInk,
                decoration: span.href == null ? null : TextDecoration.underline,
                decorationColor: span.href == null ? null : c.accentInk,
              ),
              recognizer: span.href == null ? null : _tap(span.href!),
            ),
        ],
      ),
    );
  }

  TapGestureRecognizer _tap(String href) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onOpenLink?.call(Uri.parse(href));
    _recognizers.add(recognizer);
    return recognizer;
  }
}
