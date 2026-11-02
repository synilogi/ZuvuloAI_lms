import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// A person's initials on a tinted circle. The tone is picked from the name so the same person
/// always gets the same colour; the name itself is the semantic label.
class AvatarInitials extends StatelessWidget {
  const AvatarInitials({required this.name, super.key, this.size = AvatarSizes.md});

  final String name;
  final double size;

  static const _tones = [Tone.accent, Tone.info, Tone.warn, Tone.danger, Tone.neutral];

  /// The name a greeting uses: the first word after any honorific ("Dr. Meenakshi Iyer" →
  /// "Meenakshi"), so a greeting never reads "Good afternoon, Dr.".
  static String firstNameOf(String name) {
    final words = _withoutHonorific(name).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.isEmpty ? name.trim() : words.first;
  }

  static String _withoutHonorific(String name) =>
      name.trim().replaceFirst(RegExp(r'^(Dr\.|Acharya|Pt\.)\s+', caseSensitive: false), '');

  /// The web's `initials()`: honorifics (Dr., Acharya, Pt.) dropped, first letters of the first
  /// two words, upper-cased.
  static String initialsOf(String name) {
    final words = name
        .trim()
        .replaceFirst(RegExp(r'^(Dr\.|Acharya|Pt\.)\s+', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2);
    if (words.isEmpty) return '?';
    return words.map((w) => w.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hash = name.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    final tone = context.colors.tone(_tones[hash % _tones.length]);
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tone.soft, shape: BoxShape.circle),
        child: Text(
          initialsOf(name),
          textScaler: TextScaler.noScaling,
          style: context.type.label.copyWith(color: tone.ink, fontSize: size * 0.38),
        ),
      ),
    );
  }
}
