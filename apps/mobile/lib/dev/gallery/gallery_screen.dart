import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import 'gallery_entries.dart';

/// Developer-only component gallery (§22.5): every component in every state, with switches for
/// theme, text scale, reduced motion and width. Registered only by `main_dev.dart`.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  static const routeName = '/dev/gallery';

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _dark = false;
  double _textScale = 1;
  bool _reduceMotion = false;
  bool _medium = false;

  @override
  Widget build(BuildContext context) {
    final theme = _dark ? AppTheme.dark() : AppTheme.light();
    final groups = <String, List<GalleryEntry>>{};
    for (final entry in galleryEntries) {
      groups.putIfAbsent(entry.group, () => []).add(entry);
    }
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: CommonAppBar(
            titleWidget: const Text('Component gallery'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.s3),
                child: Row(
                  children: [
                    _Toggle('Dark', _dark, (v) => setState(() => _dark = v)),
                    for (final scale in const [1.0, 1.3, 2.0])
                      _Toggle(
                        '${(scale * 100).round()}%',
                        _textScale == scale,
                        (_) => setState(() => _textScale = scale),
                      ),
                    _Toggle(
                      'Reduced motion',
                      _reduceMotion,
                      (v) => setState(() => _reduceMotion = v),
                    ),
                    _Toggle('Medium width', _medium, (v) => setState(() => _medium = v)),
                  ],
                ),
              ),
            ),
          ),
          body: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(_textScale), disableAnimations: _reduceMotion),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _medium ? 720 : 400),
                child: ListView(
                  padding: const EdgeInsets.all(Space.s4),
                  children: [
                    for (final group in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: Space.s5, bottom: Space.s2),
                        child: Text(group.key, style: context.type.titleL),
                      ),
                      for (final entry in group.value) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: Space.s4, bottom: Space.s2),
                          child: Text(
                            entry.name,
                            style: context.type.label.copyWith(color: context.colors.muted),
                          ),
                        ),
                        Builder(builder: entry.builder),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.label, this.selected, this.onChanged);

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.s2),
      child: FilterChip(label: Text(label), selected: selected, onSelected: onChanged),
    );
  }
}
