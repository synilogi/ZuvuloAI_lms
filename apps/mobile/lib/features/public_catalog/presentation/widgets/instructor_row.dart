import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../media/media.dart';
import '../../application/catalog_providers.dart';

/// An instructor on a public course page. Their photo is stored behind the API's bearer auth, so
/// a signed-out visitor sees initials — [AuthImage] falls back on its own when there is no
/// session (§13). Their email and phone are not modelled and never shown.
class InstructorRow extends StatelessWidget {
  const InstructorRow({required this.instructor, super.key});

  final Instructor instructor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthImage(
            url: instructor.photo?.url,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(Radii.pill),
            fallbackName: instructor.name,
            semanticLabel: instructor.name,
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instructor.name, style: type.titleS),
                if (instructor.title.isNotEmpty)
                  Text(instructor.title, style: type.bodyS.copyWith(color: c.muted)),
                if (instructor.bio.isNotEmpty) ...[
                  const SizedBox(height: Space.s2),
                  Text(instructor.bio, style: type.bodyS),
                ],
                if (instructor.expertise.isNotEmpty) ...[
                  const SizedBox(height: Space.s2),
                  Wrap(
                    spacing: Space.s2,
                    runSpacing: Space.s1,
                    children: [
                      for (final area in instructor.expertise)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.s2,
                            vertical: Space.s1,
                          ),
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Text(area, style: type.caption.copyWith(color: c.muted)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
