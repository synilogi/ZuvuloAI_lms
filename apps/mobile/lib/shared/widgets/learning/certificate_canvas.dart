import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart' show Tokens;
import '../../../l10n/l10n.dart';

/// The template's `CertificateAccent` (`packages/domain/src/certificate.ts`), mapped onto the
/// existing tone families — no new hues (§22.7).
enum CertificateAccent {
  emerald,
  saffron,
  indigo;

  static CertificateAccent parse(String? value) => CertificateAccent.values.firstWhere(
    (a) => a.name == value,
    orElse: () => CertificateAccent.indigo,
  );

  Tone get tone => switch (this) {
    CertificateAccent.emerald => Tone.info,
    CertificateAccent.saffron => Tone.warn,
    CertificateAccent.indigo => Tone.accent,
  };
}

@immutable
class CertificateSignatory {
  const CertificateSignatory({required this.name, required this.title});

  final String name;
  final String title;
}

/// Everything the canvas draws; FLUTTER-014 fills it from the server's certificate and template.
@immutable
class CertificateCanvasData {
  const CertificateCanvasData({
    required this.academyName,
    required this.heading,
    required this.statement,
    required this.learnerName,
    required this.courseTitle,
    required this.credentialId,
    required this.accent,
    this.details = const [],
    this.issuedOnLabel,
    this.signatories = const [],
  });

  final String academyName;
  final String heading;
  final String statement;
  final String learnerName;
  final String courseTitle;
  final String credentialId;
  final CertificateAccent accent;

  /// Extra facts ("Score 92%", "24 hours").
  final List<String> details;

  /// Formatted issue date, or null while pending.
  final String? issuedOnLabel;
  final List<CertificateSignatory> signatories;
}

/// The paper is always drawn in the light palette — it is a document, in either app theme.
///
/// A landscape certificate rendered at a fixed design size and scaled to fit, so it stays
/// legible and proportionate on phones, tablets and in landscape (LMS-011).
class CertificateCanvas extends StatelessWidget {
  const CertificateCanvas({required this.data, required this.semanticLabel, super.key});

  final CertificateCanvasData data;

  /// Summary for screen readers (the drawn text is decorative once scaled).
  final String semanticLabel;

  static const designSize = Size(842, 595);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: designSize.aspectRatio,
        child: FittedBox(
          child: MediaQuery.withNoTextScaling(
            child: SizedBox.fromSize(
              size: designSize,
              child: _Paper(data: data),
            ),
          ),
        ),
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.data});

  final CertificateCanvasData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final tone = c.tone(data.accent.tone);
    final t = context.type;
    final ink = Tokens.light.text;
    final muted = Tokens.light.muted;
    Text line(String text, TextStyle style) =>
        Text(text, textAlign: TextAlign.center, style: style);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.light.surface,
        border: Border.all(color: tone.solid, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: tone.solid.withValues(alpha: 0.35))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 36, 56, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tone.solid,
                        boxShadow: [
                          BoxShadow(color: tone.solid.withValues(alpha: 0.25), spreadRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(data.academyName, style: t.label.copyWith(color: muted, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 22),
                line(
                  data.heading.toUpperCase(),
                  t.label.copyWith(color: tone.ink, letterSpacing: 3, fontSize: 15),
                ),
                const SizedBox(height: 14),
                line(l10n.certificateAwardedTo, t.bodyM.copyWith(color: muted)),
                const SizedBox(height: 6),
                line(
                  data.learnerName,
                  t.editorial.copyWith(color: ink, fontSize: 46, height: 1.15),
                ),
                const SizedBox(height: 8),
                line(data.statement, t.bodyM.copyWith(color: muted)),
                const SizedBox(height: 6),
                line(data.courseTitle, t.editorial.copyWith(color: ink, fontSize: 26)),
                if (data.details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  line(data.details.join('  ·  '), t.bodyS.copyWith(color: muted)),
                ],
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: data.signatories.isEmpty
                          ? const SizedBox.shrink()
                          : _SignOff(
                              top: data.signatories.first.name,
                              caption: data.signatories.first.title,
                              ink: ink,
                              muted: muted,
                            ),
                    ),
                    _Seal(color: Tokens.light.warn, ink: Tokens.light.warnInk),
                    Expanded(
                      child: data.signatories.length > 1
                          ? _SignOff(
                              top: data.signatories[1].name,
                              caption: data.signatories[1].title,
                              ink: ink,
                              muted: muted,
                            )
                          : _SignOff(
                              top: data.issuedOnLabel ?? '—',
                              caption: l10n.certificateDateOfIssue,
                              ink: ink,
                              muted: muted,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                line(
                  l10n.certificateCredentialId(data.credentialId),
                  t.caption.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOff extends StatelessWidget {
  const _SignOff({
    required this.top,
    required this.caption,
    required this.ink,
    required this.muted,
  });

  final String top;
  final String caption;
  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          top,
          textAlign: TextAlign.center,
          style: context.type.titleS.copyWith(color: ink),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          width: 180,
          height: 1,
          color: muted,
        ),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: context.type.caption.copyWith(color: muted),
        ),
      ],
    );
  }
}

/// The gold seal with the brand's halo ring.
class _Seal extends StatelessWidget {
  const _Seal({required this.color, required this.ink});

  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: ink.withValues(alpha: 0.4), width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(PhosphorIconsFill.sealCheck, color: ink, size: 40),
        ),
      ),
    );
  }
}
